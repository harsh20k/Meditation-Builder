variable "github_org" {
  description = "GitHub organization or user that owns the repo."
  type        = string
  default     = "harsh20k"
}

variable "github_repo" {
  description = "GitHub repository name (CI assumes this role via OIDC)."
  type        = string
  default     = "Meditation-Builder"
}

variable "github_actions_role_name" {
  description = "IAM role name GitHub Actions assumes for terraform plan/apply."
  type        = string
  default     = "github-actions-meditation-builder"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub Actions OIDC root CA thumbprint (stable).
  thumbprint_list = ["6938fd4d98bab03faae97a3778ef91793141c7ce"]
}

resource "aws_iam_role" "github_actions" {
  name = var.github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name    = var.github_actions_role_name
    Project = "meditation-builder"
  }
}

# Broad permissions for terraform apply; scope down once CI stabilizes.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
