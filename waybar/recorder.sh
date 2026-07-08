#!/bin/bash
export PYTHONUNBUFFERED=1

update_state() {
    # Find the PID of wf-recorder
    if PID=$(pgrep -x wf-recorder | head -n 1); then
        echo '{"text": "<span color='\''#f7768e'\''>  </span>", "tooltip": "Recording...\n\nLeft Click: Stop Recording", "class": "recording"}'
        
        # Block natively until wf-recorder exits (0% CPU)
        # tail --pid uses OS-level wait mechanisms natively without brute-force polling
        tail --pid=$PID -f /dev/null
        
        # When it exits (via stop script, crash, or manual kill), clear the icon instantly
        echo '{"text": "", "tooltip": ""}'
    else
        echo '{"text": "", "tooltip": ""}'
    fi
}

# Run once at startup
update_state

# Define a trap to wake up from sleep when toggle_recorder.sh sends a signal
trap "update_state" SIGRTMIN+9

while true; do
    # Sleep fully idle until a signal interrupts it
    sleep infinity & wait $!
done
