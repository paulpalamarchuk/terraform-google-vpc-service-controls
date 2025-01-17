module "event_folder_log_entry" {
  source  = "terraform-google-modules/event-function/google//modules/event-folder-log-entry"
  version = "1.1.0"

  filter     = <<EOF
resource.type="project" AND
protoPayload.serviceName="cloudresourcemanager.googleapis.com" AND
(protoPayload.methodName="CreateProject" OR protoPayload.methodName="DeleteProject" OR protoPayload.methodName="UpdateProject")
EOF
  name       = local.watcher_name
  project_id = var.project_id
  folder_id  = var.folder_id
}

resource "google_service_account" "watcher" {
  project = var.project_id

  account_id   = local.watcher_name
  display_name = local.watcher_name
}

module "localhost_function" {
  source  = "terraform-google-modules/event-function/google"
  version = "1.1.0"

  description = "Adds projects to VPC service permiterer."
  entry_point = "handler"

  environment_variables = {
    FOLDER_ID = var.folder_id
  }

  event_trigger    = module.event_folder_log_entry.function_event_trigger
  name             = local.watcher_name
  project_id       = var.project_id
  region           = var.region
  source_directory = abspath(path.module)
  runtime          = "python37"
  //  runtime               = "go111"
  available_memory_mb   = 2048
  timeout_s             = 540
  service_account_email = google_service_account.watcher.email
}
