#!/bin/bash
# Polls for vercel auth completion, then runs the setup
echo "Watching for Vercel auth completion..."
echo "Script PID: $$"
echo "Started at: $(date)"
echo ""

# Kill existing vercel login if it's hung
if ! ps aux | grep -q "[v]ercel login"; then
    echo "Starting vercel login..."
    export PATH=$PATH:/home/agent/.npm-global/bin
    vercel login 2>&1 &
fi

# Poll for auth.json
for i in $(seq 1 600); do
    if [ -f "$HOME/.vercel/auth.json" ]; then
        VTOKEN=$(cat "$HOME/.vercel/auth.json" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).token)}catch(e){console.error('no token')}})" 2>/dev/null)
        if [ -n "$VTOKEN" ] && [ "$VTOKEN" != "no token" ]; then
            echo "✅ Auth completed at $(date)! Token obtained."
            echo "Token: ${VTOKEN:0:8}..."
            echo ""
            # Save token to file for the main script
            echo "$VTOKEN" > /tmp/vercel_token.txt
            # Run the main setup
            export VERCEL_TOKEN_OBTAINED="$VTOKEN"
            # GITHUB_TOKEN is inherited from parent process environment
            bash /workspace/scripts/setup-vercel-deploy.sh 2>&1
            exit 0
        fi
    fi
    sleep 1
done

echo "Timeout reached. Auth not completed."
exit 1
