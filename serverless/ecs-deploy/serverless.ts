import type { AWS } from '@serverless/typescript'

import slackConfirm from '@functions/slack-confirm'
import deployExec   from '@functions/deploy-exec'

const serverlessConfiguration: AWS = {
  useDotenv:        true,
  service:          'ecs-deploy',
  frameworkVersion: '3',
  plugins:          ['serverless-esbuild'],
  provider: {
    name:    'aws',
    runtime: 'nodejs18.x',
    region:  'ap-northeast-1',
    stage:   'prod',
    iam:     { role: `arn:aws:iam::${process.env.AWS_ACCOUNT_ID}:role/serverless_role`}
  },
  functions: {
    slackConfirm,
    deployExec
  },
  package: { individually: true },
  custom: {
    esbuild: {
      bundle:      true,
      minify:      false,
      sourcemap:   true,
      exclude:     ['aws-sdk'],
      target:      'node18',
      define:      { 'require.resolve': undefined },
      platform:    'node',
      concurrency: 10,
    }
  }
}

module.exports = serverlessConfiguration
