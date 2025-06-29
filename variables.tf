variable "folder_create" {
  type        = bool
  description = "Do the folder creation?"
  default     = false
}

variable "folder_id" {
  type        = string
  description = "folder-id for the deployment"
  default     = null
}

variable "folder_name" {
  type        = string
  description = "folder name"
  default     = null
}

variable "folder_description" {
  type        = string
  description = "folder description"
  default     = null
}

variable "uniq_names" {
  type        = bool
  description = "Make names unique?"
  default     = true
}

variable "uniq_suffix" {
  type        = string
  description = "Unique name suffix"
  default     = "todo-app"
}

variable "zone_1" {
  type        = string
  description = "zone 1"
  default     = "ru-central1-a"
}

variable "zone_2" {
  type        = string
  description = "zone 2"
  default     = "ru-central1-b"
}

variable "zone_3" {
  type        = string
  description = "zone 3"
  default     = "ru-central1-d"
}

variable "os_user_pubkey_file" {
  type        = string
  description = "os user pubkey filename"
  default     = null
}

variable "os_user_pubkey" {
  type        = string
  description = "os user pubkey"
  default     = ""
}

variable "os_user" {
  type        = string
  description = "os username"
  default     = "ubuntu"
}

variable "target_host" {
  type        = string
  description = "Target host"
}
