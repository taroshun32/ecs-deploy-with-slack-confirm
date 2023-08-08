resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

resource "aws_iam_role" "github_actions" {
  name               = "github_actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_dynamo_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:taroshun32/taroshun32-actions:*",
        "repo:taroshun32/ecs-deploy-with-slack-confirm:*"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [ aws_iam_openid_connect_provider.github_actions.arn ]
    }
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = aws_iam_role.github_actions.name
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions.json
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["*"]
  }

  statement {
    sid       = "2"
    effect    = "Allow"
    actions   = ["ecs:*"]
    resources = ["*"]
  }

  statement {
    sid       = "3"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ecs_task_execution_role.arn]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

resource "aws_iam_role" "serverless_role" {
  name               = "serverless_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "serverless_policy" {
  name   = "serverless_policy"
  policy = data.aws_iam_policy_document.serverless_policy.json
}

data "aws_iam_policy_document" "serverless_policy" {
  statement {
    sid = "1"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:ap-northeast-1:${var.aws_account_id}:parameter/GITHUB_APP_ID",
      "arn:aws:ssm:ap-northeast-1:${var.aws_account_id}:parameter/GITHUB_SECRET_KEY",
      "arn:aws:ssm:ap-northeast-1:${var.aws_account_id}:parameter/SLACK_BOT_TOKEN",
      "arn:aws:ssm:ap-northeast-1:${var.aws_account_id}:parameter/SLACK_VERIFICATION_TOKEN"
    ]
  }

  statement {
    sid = "2"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid = "3"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:TagResource"
    ]
    resources = [
      "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:log-group:/aws/lambda/slack-confirm:*",
      "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:log-group:/aws/lambda/deploy-exec:*"
    ]
  }

  statement {
    sid = "4"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:log-group:/aws/lambda/slack-confirm:*:*",
      "arn:aws:logs:ap-northeast-1:${var.aws_account_id}:log-group:/aws/lambda/deploy-exec:*:*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "serverless_policy" {
  role       = aws_iam_role.serverless_role.name
  policy_arn = aws_iam_policy.serverless_policy.arn
}

resource "aws_iam_role_policy_attachment" "serverless_dynamo_policy" {
  role       = aws_iam_role.serverless_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}
