resource "aws_cognito_user_pool" "main" {
  name = "${var.name_prefix}-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name = "${var.name_prefix}-user-pool"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.cognito_domain_prefix}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_identity_provider" "apple" {
  count = var.apple_services_id != "" ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "SignInWithApple"
  provider_type = "SignInWithApple"

  provider_details = {
    client_id   = var.apple_services_id
    team_id     = var.apple_team_id
    key_id      = var.apple_key_id
    private_key = var.apple_private_key
    authorize_scopes = "email name"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

resource "aws_cognito_user_pool_client" "ios" {
  name         = "${var.name_prefix}-ios-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client   = true
  allowed_oauth_flows                    = ["code"]
  allowed_oauth_scopes                   = ["email", "openid", "profile"]
  supported_identity_providers           = var.apple_services_id != "" ? ["SignInWithApple"] : []
  callback_urls                          = ["https://localhost/callback"]
  logout_urls                            = ["https://localhost/logout"]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}

resource "aws_ssm_parameter" "user_pool_id" {
  name  = "/mb/${var.environment}/cognito/user-pool-id"
  type  = "String"
  value = aws_cognito_user_pool.main.id
}

resource "aws_ssm_parameter" "app_client_id" {
  name  = "/mb/${var.environment}/cognito/app-client-id"
  type  = "String"
  value = aws_cognito_user_pool_client.ios.id
}

resource "aws_ssm_parameter" "cognito_domain" {
  name  = "/mb/${var.environment}/cognito/domain"
  type  = "String"
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

data "aws_region" "current" {}
