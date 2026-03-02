#!/bin/bash

# Analyst Scheduler Manager
# 스케줄러 관리 스크립트

LOCK_FILE=".analyst-scheduler.lock"
PID_FILE=".analyst-scheduler.pid"
TRACKER_FILE=".analyst-api-calls.json"

case "$1" in
    start)
        echo "🚀 Starting Analyst Scheduler..."
        npx tsx scripts/analyst_scheduler_improved.ts > logs/analyst-scheduler.log 2>&1 &
        echo "✅ Scheduler started. Check logs with: tail -f logs/analyst-scheduler.log"
        ;;

    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            echo "🛑 Stopping Scheduler (PID: $PID)..."
            kill "$PID" 2>/dev/null
            rm -f "$LOCK_FILE" "$PID_FILE"
            echo "✅ Scheduler stopped"
        else
            echo "❌ Scheduler is not running"
        fi
        ;;

    restart)
        $0 stop
        sleep 2
        $0 start
        ;;

    status)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                echo "✅ Scheduler is running (PID: $PID)"

                # Show API usage
                if [ -f "$TRACKER_FILE" ]; then
                    echo ""
                    echo "📊 Today's API Usage:"
                    cat "$TRACKER_FILE" | jq '.'
                fi
            else
                echo "❌ Scheduler is not running (stale PID file)"
                rm -f "$LOCK_FILE" "$PID_FILE"
            fi
        else
            echo "❌ Scheduler is not running"
        fi
        ;;

    clean)
        echo "🧹 Cleaning up stale files..."
        rm -f "$LOCK_FILE" "$PID_FILE"
        echo "✅ Cleanup complete"
        ;;

    usage)
        if [ -f "$TRACKER_FILE" ]; then
            echo "📊 API Usage Statistics:"
            cat "$TRACKER_FILE" | jq '.'
        else
            echo "❌ No usage data available"
        fi
        ;;

    reset-limit)
        echo "⚠️  Resetting daily API limit..."
        rm -f "$TRACKER_FILE"
        echo "✅ Limit reset. New day counter started."
        ;;

    *)
        echo "Analyst Scheduler Manager"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|clean|usage|reset-limit}"
        echo ""
        echo "Commands:"
        echo "  start       - Start the scheduler"
        echo "  stop        - Stop the scheduler"
        echo "  restart     - Restart the scheduler"
        echo "  status      - Check scheduler status"
        echo "  clean       - Remove stale lock files"
        echo "  usage       - Show API usage statistics"
        echo "  reset-limit - Reset daily API call limit"
        exit 1
        ;;
esac
