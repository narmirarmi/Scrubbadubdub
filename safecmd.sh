#!/bin/bash
#
# safecmd.sh - Role-based command safety wrapper
# This script prevents execution of dangerous commands based on user roles
# and implements safeguards against destructive operations.

# Configuration - in production this would be in a separate file
# User roles: admin, operator, developer
declare -A USER_ROLES
USER_ROLES=([root]="admin" [ubuntu]="admin" [demo_admin]="admin" [demo_operator]="operator" [demo_dev]="developer")

# Commands allowed per role
declare -A ROLE_PERMISSIONS
ROLE_PERMISSIONS=(
  [admin]="rm,chmod,chown,dd,mv,rsync"
  [operator]="rm,mv,rsync"
  [developer]="rm"
)

# Dangerous patterns to check for each command
declare -A DANGEROUS_PATTERNS
DANGEROUS_PATTERNS=(
  [rm]="^rm\s+(-[^-]*f[^-]*|-[^-]*r[^-]*f|-[^-]*f[^-]*r)\s+/.*$|^rm\s+(-[^-]*f[^-]*|-[^-]*r[^-]*f|-[^-]*f[^-]*r)\s+\.\.|^rm\s+(-[^-]*f[^-]*|-[^-]*r[^-]*f|-[^-]*f[^-]*r)\s+[^/]+/\.\."
  [chmod]="^chmod\s+(-[^-]*R|-[^-]*r)\s+777\s+/.*$"
  [chown]="^chown\s+(-[^-]*R|-[^-]*r)\s+.*\s+/.*$"
  [dd]="^dd\s+.*\s+of=/dev/(sd|hd|nvme).*$"
  [mv]="^mv\s+.*\s+/\s*$|^mv\s+/\s+.*$"
  [rsync]="^rsync\s+(-[^-]*delete[^-]*)\s+.*$"
)

# Function to check if a command is dangerous
is_dangerous() {
  local cmd="$1"
  local command_pattern="${DANGEROUS_PATTERNS[$cmd]}"

  if [[ -z "$command_pattern" ]]; then
    return 1  # Not dangerous if no pattern defined
  fi

  if [[ "$FULL_COMMAND" =~ $command_pattern ]]; then
    return 0  # Dangerous
  fi

  return 1  # Not dangerous
}

# Function to get the base command from the full command
get_base_command() {
  echo "$1" | awk '{print $1}' | xargs basename
}

# Get user role
CURRENT_USER=$(whoami)
USER_ROLE=${USER_ROLES[$CURRENT_USER]}

if [[ -z "$USER_ROLE" ]]; then
  echo "Error: No role defined for user $CURRENT_USER"
  exit 1
fi

# Get the command to execute
FULL_COMMAND="$@"
BASE_COMMAND=$(get_base_command "$FULL_COMMAND")

# Check if command is allowed for this role
IFS=',' read -ra ALLOWED_COMMANDS <<< "${ROLE_PERMISSIONS[$USER_ROLE]}"
COMMAND_ALLOWED=0

for cmd in "${ALLOWED_COMMANDS[@]}"; do
  if [[ "$cmd" == "$BASE_COMMAND" ]]; then
    COMMAND_ALLOWED=1
    break
  fi
done

if [[ "$COMMAND_ALLOWED" -eq 0 ]]; then
  echo "Error: You don't have permission to run '$BASE_COMMAND'"
  echo "Your role ($USER_ROLE) doesn't allow this command."
  exit 1
fi

# Check if command usage is dangerous
if is_dangerous "$BASE_COMMAND"; then
  echo "WARNING: This command appears to be dangerous!"
  echo "Command: $FULL_COMMAND"

  # For rm commands with recursive and force flags targeting root directories
  if [[ "$BASE_COMMAND" == "rm" && "$FULL_COMMAND" =~ rm[[:space:]]+-[^-]*rf[^-]*[[:space:]]+/ ]]; then
    echo "CRITICAL: Attempt to recursively remove files from root directory detected!"
    echo "This operation is blocked as it could cause catastrophic system damage."

    # Suggest safer alternative
    echo ""
    echo "Consider a safer alternative instead:"
    echo "- Specify exact directories to remove"
    echo "- Use --preserve-root option"
    echo "- List files before removing with: ls [path]"
    exit 1
  fi

  # Request confirmation
  read -p "Do you want to proceed? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Command aborted."
    exit 0
  fi

  # For admin users, require additional verification for very dangerous commands
  if [[ "$USER_ROLE" == "admin" && ("$FULL_COMMAND" =~ rm[[:space:]]+-[^-]*rf[^-]*[[:space:]]+ || "$FULL_COMMAND" =~ dd[[:space:]]+.*of=/dev/) ]]; then
    # Generate a random 6-digit verification code
    VERIFICATION_CODE=$(( 100000 + RANDOM % 900000 ))
    echo ""
    echo "This is a highly destructive command."
    echo "To proceed, please enter verification code: $VERIFICATION_CODE"

    read -p "Verification code: " input_code
    if [[ "$input_code" != "$VERIFICATION_CODE" ]]; then
      echo "Incorrect verification code. Command aborted."
      echo "This event has been logged."
      # In a real system, log this attempt to a secure log file
      exit 1
    fi
  fi
fi

# If we got here, execute the command
echo "Executing: $FULL_COMMAND"
# For demo purposes, we'll just echo the command
# In production, uncomment the next line to actually execute the command
# eval "$FULL_COMMAND"
echo "[DEMO MODE] Command would be executed in production"