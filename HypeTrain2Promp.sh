#!/bin/zsh

# HypeTrain Backend Code2Prompt Chunking Functions and Aliases
# Source this file from your .zshrc to make the hc2p* aliases available.

export HYPETRAIN_REPO_PATH="/Users/user/__Repositories/hypetrain-backend"
export C2P_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh"
export HT_INFRA_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/HypeTrainInfra2Promp.sh"

# --- Helper function template ---
_hc2p_run_chunk() {
  local chunk_name="$1"
  shift # Remove chunk name from arguments
  local target_paths=("$@") # Remaining arguments are paths

  # Check if essential variables are set
  if [[ -z "$HYPETRAIN_REPO_PATH" || -z "$C2P_SCRIPT_PATH" ]]; then
    echo "Error: HYPETRAIN_REPO_PATH or C2P_SCRIPT_PATH is not set." >&2
    return 1
  fi
  if [[ ! -d "$HYPETRAIN_REPO_PATH" ]]; then
    echo "Error: HypeTrain repo path not found: $HYPETRAIN_REPO_PATH" >&2
    return 1
  fi
  if [[ ! -f "$C2P_SCRIPT_PATH" ]]; then
     echo "Error: code2prompt script not found: $C2P_SCRIPT_PATH" >&2
     return 1
  fi

  echo "--- Generating HypeTrain Chunk: ${chunk_name} ---"
  local current_dir=$(pwd)
  cd "$HYPETRAIN_REPO_PATH" || { echo "Error: Could not cd to $HYPETRAIN_REPO_PATH"; return 1; }

  # Use the basename of the first path for the output file name hint
  local base_name_hint=$(basename "${target_paths[0]}")

  "$C2P_SCRIPT_PATH" "${target_paths[@]}" "${base_name_hint}" # Pass paths and hint correctly
  local exit_code=$?
  cd "$current_dir"
  if [ $exit_code -eq 0 ]; then
    echo "--- Chunk ${chunk_name} Done ---"
  else
    echo "--- Chunk ${chunk_name} Failed ---"
    return 1
  fi
  return 0
}

# --- App Chunks ---
# Pass the full app directory, not just src, so basename works for filename
_hc2p_app_api() { _hc2p_run_chunk "App-API" "apps/hypetrain-api"; }
_hc2p_app_billing() { _hc2p_run_chunk "App-Billing" "apps/hypetrain-billing-service"; }
_hc2p_app_contracting() { _hc2p_run_chunk "App-Contracting" "apps/hypetrain-contracting-service"; }
_hc2p_app_exploration() { _hc2p_run_chunk "App-Exploration" "apps/hypetrain-exploration-service"; }
_hc2p_app_external_api() { _hc2p_run_chunk "App-ExternalAPI" "apps/hypetrain-external-api-service"; }
_hc2p_app_message_processing() { _hc2p_run_chunk "App-MessageProcessing" "apps/hypetrain-message-processing-service"; }
_hc2p_app_migration_runner() { _hc2p_run_chunk "App-MigrationRunner" "apps/hypetrain-migration-runner"; }
_hc2p_app_notification() { _hc2p_run_chunk "App-Notification" "apps/hypetrain-notification-service"; }
_hc2p_app_scheduler() { _hc2p_run_chunk "App-Scheduler" "apps/hypetrain-scheduler-service"; }
_hc2p_app_search() { _hc2p_run_chunk "App-Search" "apps/hypetrain-search-service"; }
_hc2p_app_storage() { _hc2p_run_chunk "App-Storage" "apps/hypetrain-storage-service"; }

# --- Lib Chunks ---
# Pass the full lib directory
_hc2p_lib_analytics() { _hc2p_run_chunk "Lib-Analytics" "libs/analytics"; }
_hc2p_lib_cqrs() { _hc2p_run_chunk "Lib-CQRS" "libs/cqrs"; }
_hc2p_lib_ht_logger() { _hc2p_run_chunk "Lib-HTLogger" "libs/ht-logger"; }
_hc2p_lib_common() { _hc2p_run_chunk "Lib-Common" "libs/hypetrain-common"; }
_hc2p_lib_integration_events() { _hc2p_run_chunk "Lib-IntegrationEvents" "libs/integration-events"; }
_hc2p_lib_shared() { _hc2p_run_chunk "Lib-Shared" "libs/shared"; }

# --- Infra Chunk Function (Now just calls the external script) ---
_hc2p_infra() {
  echo "--- Generating HypeTrain Chunk: Infra ---"
  if [[ ! -f "$HT_INFRA_SCRIPT_PATH" ]]; then
     echo "Error: HypeTrain infra script not found: $HT_INFRA_SCRIPT_PATH" >&2
     return 1
  fi
  # Ensure script is executable
  chmod +x "$HT_INFRA_SCRIPT_PATH"
  # Execute the script
  "$HT_INFRA_SCRIPT_PATH"
  local exit_code=$?
   if [ $exit_code -ne 0 ]; then
     echo "--- Chunk Infra Failed ---"
     return 1
   # The script itself prints the Done message
   fi
   return 0
}


# --- User-facing Aliases ---
# Apps
alias hc2pApi='_hc2p_app_api'
alias hc2pBilling='_hc2p_app_billing'
alias hc2pContracting='_hc2p_app_contracting'
alias hc2pExploration='_hc2p_app_exploration'
alias hc2pExternalApi='_hc2p_app_external_api'
alias hc2pMessageProcessing='_hc2p_app_message_processing'
alias hc2pMigrationRunner='_hc2p_app_migration_runner'
alias hc2pNotification='_hc2p_app_notification'
alias hc2pScheduler='_hc2p_app_scheduler'
alias hc2pSearch='_hc2p_app_search'
alias hc2pStorage='_hc2p_app_storage'
# Libs
alias hc2pAnalytics='_hc2p_lib_analytics'
alias hc2pCqrs='_hc2p_lib_cqrs'
alias hc2pLogger='_hc2p_lib_ht_logger'
alias hc2pCommon='_hc2p_lib_common'
alias hc2pIntegrationEvents='_hc2p_lib_integration_events'
alias hc2pShared='_hc2p_lib_shared'
# Infra
alias hc2pInfra='_hc2p_infra' # Alias now calls the helper function which runs the script

# --- Aggregate Aliases ---
alias hc2pAllApps='_hc2p_app_api && _hc2p_app_billing && _hc2p_app_contracting && _hc2p_app_exploration && _hc2p_app_external_api && _hc2p_app_message_processing && _hc2p_app_migration_runner && _hc2p_app_notification && _hc2p_app_scheduler && _hc2p_app_search && _hc2p_app_storage'
alias hc2pAllLibs='_hc2p_lib_analytics && _hc2p_lib_cqrs && _hc2p_lib_ht_logger && _hc2p_lib_common && _hc2p_lib_integration_events && _hc2p_lib_shared'
alias hc2pEverything='hc2pAllApps && hc2pAllLibs && hc2pInfra'

echo "HypeTrain chunking aliases (hc2p*) loaded."
