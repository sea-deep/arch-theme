#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/inotify.h>
#include <poll.h>
#include <signal.h>

static volatile sig_atomic_t g_running = 1;

static void handle_sig(int sig) {
    (void)sig;
    g_running = 0;
}

static int is_watched_target(const char *target, char **watched, int watched_count) {
    for (int i = 0; i < watched_count; i++) {
        if (strcmp(target, watched[i]) == 0) return 1;
    }
    return 0;
}

static int check_any_device_open(char **watched, int watched_count) {
    DIR *proc = opendir("/proc");
    if (!proc) return 0;
    struct dirent *ent;
    char fd_dir[1024];
    char target[1024];
    int found = 0;

    while ((ent = readdir(proc)) != NULL) {
        if (ent->d_name[0] < '0' || ent->d_name[0] > '9') continue;
        snprintf(fd_dir, sizeof(fd_dir), "/proc/%s/fd", ent->d_name);
        DIR *fdd = opendir(fd_dir);
        if (!fdd) continue;
        struct dirent *fe;
        while ((fe = readdir(fdd)) != NULL) {
            if (fe->d_name[0] == '.') continue;
            char path[2048];
            snprintf(path, sizeof(path), "%s/%s", fd_dir, fe->d_name);
            ssize_t len = readlink(path, target, sizeof(target) - 1);
            if (len > 0) {
                target[len] = '\0';
                if (is_watched_target(target, watched, watched_count)) {
                    found = 1;
                    closedir(fdd);
                    closedir(proc);
                    return 1;
                }
            }
        }
        closedir(fdd);
    }
    closedir(proc);
    return found;
}

int main(int argc, char *argv[]) {
    signal(SIGINT, handle_sig);
    signal(SIGTERM, handle_sig);

    char *default_devices[] = {"/dev/video0", "/dev/video2"};
    char **devices = default_devices;
    int num_devices = 2;

    if (argc > 1) {
        devices = &argv[1];
        num_devices = argc - 1;
    }

    int ifd = inotify_init1(IN_CLOEXEC);
    if (ifd < 0) return 1;

    for (int i = 0; i < num_devices; i++) {
        inotify_add_watch(ifd, devices[i], IN_OPEN | IN_CLOSE_WRITE | IN_CLOSE_NOWRITE);
    }

    int current_state = check_any_device_open(devices, num_devices);
    printf("%d\n", current_state);
    fflush(stdout);

    char buf[4096];
    while (g_running) {
        struct pollfd pfd = { .fd = ifd, .events = POLLIN };
        int pr = poll(&pfd, 1, -1);
        if (pr <= 0) {
            if (!g_running) break;
            continue;
        }

        ssize_t len = read(ifd, buf, sizeof(buf));
        if (len <= 0) {
            if (!g_running) break;
            continue;
        }

        // Drain any burst events in the queue within 60ms
        while (poll(&pfd, 1, 60) > 0 && (pfd.revents & POLLIN)) {
            read(ifd, buf, sizeof(buf));
        }

        int new_state = check_any_device_open(devices, num_devices);
        if (new_state != current_state) {
            current_state = new_state;
            printf("%d\n", current_state);
            fflush(stdout);
        }
    }

    close(ifd);
    return 0;
}
