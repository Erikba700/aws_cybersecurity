variable "project" {
  description = "The name of the project"
  type        = string
}

variable "name" {
  type = string
  description = "The name of the parameter"
}

variable "description" {
  type        = string
  default     = ""
  description = "A description of the parameter."
}

variable "type" {
  type        = string
  default     = "String"
  description = "The type of the parameter. Valid types: String, StringList, SecureString."
}

variable "value" {
  description = "The value of the parameter."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the parameter."
  default     = {}
}