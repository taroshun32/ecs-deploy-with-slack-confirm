import axios from 'axios'
import {
  APIGatewayProxyEvent,
  APIGatewayProxyResult
} from 'aws-lambda'

import { requestGithubToken } from '@libs/request-github-token'
import { middyfy }            from '@libs/middleware/lambda'

const deployExec = async (
  event: APIGatewayProxyEvent,
  context
): Promise<APIGatewayProxyResult> => {

  const body = JSON.parse(decodeURIComponent(atob(event.body)).replace('payload=', ''))

  if (body.token !== context.SLACK_VERIFICATION_TOKEN)
    return { statusCode: 400, body: 'トークンが無効です。' }

  const slackAction = body.actions[0]

  if (slackAction.name === 'not_deploy')
    return { statusCode: 200, body: 'デプロイを中止しました。\n実行者: ' + body.user.name }

  const accessToken = await requestGithubToken(context.GITHUB_APP_ID, context.GITHUB_SECRET_KEY)

  // actions を dispatch する
  await axios.post(
    `https://api.github.com/repos/taroshun32/ecs-deploy-with-slack-confirm/actions/workflows/ecs-${slackAction.name}.yml/dispatches`,
    {
      ref:    'main',
      inputs: {
        REPOSITORY: slackAction.value.split(':')[0],
        TAG:        slackAction.value.split(':')[1]
      }
    },
    {
      headers: {
        Authorization: 'token ' + accessToken,
        Accept:        'application/vnd.github.v3+json'
      }
    }
  )

  const eventType = (slackAction.name === 'deploy') ? 'デプロイ' : 'ロールバック'
  return { statusCode: 200, body: `${eventType}を開始します。\n実行者: ${body.user.name}` }
}

export const main = middyfy(deployExec)
