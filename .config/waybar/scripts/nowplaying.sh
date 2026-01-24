#!/bin/bash

# Get player status
STATUS=$(playerctl status 2>/dev/null)

if [[ "$STATUS" == "Playing" ]] || [[ "$STATUS" == "Paused" ]]; then
    ARTIST=$(playerctl metadata artist 2>/dev/null | cut -c1-20)
    TITLE=$(playerctl metadata title 2>/dev/null | cut -c1-25)
    
    if [[ "$STATUS" == "Playing" ]]; then
        ICON=""
    else
        ICON=""
    fi
    
    if [[ -n "$TITLE" ]]; then
        if [[ -n "$ARTIST" ]]; then
            echo "[ $ICON $TITLE - $ARTIST ]"
        else
            echo "[ $ICON $TITLE ]"
        fi
    else
        echo ""
    fi
else
    echo ""
fi
