import axios         from 'axios'
import { WebClient } from '@slack/web-api'
import {
  DynamoDBClient,
  GetItemCommand
} from '@aws-sdk/client-dynamodb'

import { requestGithubToken } from '@libs/request-github-token'
import { middyfy }            from '@libs/middleware/lambda'

async function slackConfirm(event, context) {

  // -- ECR Value --
  const repository = event.detail['repository-name']
  const tag        = event.detail['image-tag']

  // -- Client --
  const slackClient    = new WebClient(context.SLACK_BOT_TOKEN)
  const dynamoDBClient = new DynamoDBClient({ region: 'ap-northeast-1' })

  const ecsDeployParams = (await dynamoDBClient.send(
    new GetItemCommand({
      TableName: 'ecs_map',
      Key:       { repository: { S: repository } }
    })
  )).Item

  await slackClient.chat.postMessage({
    channel:     ecsDeployParams.channel.S,
    blocks:      [{ type: "divider" }],
    attachments: [
      {
        text:   "イメージがアップされました。",
        fields: [
          { short: true, value: repository, title: "Repository" },
          { short: true, value: tag,        title: "Tag"        }
        ]
      }
    ]
  })

  if (ecsDeployParams['auto-deploy'].BOOL) {
    //-------------------------------------------------------
    // auto-deploy が true の場合は ecs-deploy を dispatch する
    //-------------------------------------------------------
    await slackClient.chat.postMessage({
      channel: ecsDeployParams.channel.S,
      blocks:  [
        {
          type: "section",
          text: { type: "plain_text", text: "デプロイを開始します。" }
        }
      ]
    })

    const accessToken = await requestGithubToken(context.GITHUB_APP_ID, context.GITHUB_SECRET_KEY)
    await axios.post(
      'https://api.github.com/repos/taroshun32/taroshun32-actions/dispatches',
      {
        event_type:     'ecs-deploy',
        client_payload: {
          REPOSITORY:   repository,
          TAG:          tag,
        }
      },
      {
        headers: {
          Authorization: 'token ' + accessToken,
          Accept:        'application/vnd.github.v3+json'
        }
      }
    )
  } else {
    //--------------------------------------------
    // auto-deploy が false の場合は slack 確認を行う
    //--------------------------------------------
    await slackClient.chat.postMessage({
      channel:     ecsDeployParams.channel.S,
      attachments: [
        {
          callback_id: "confirm",
          text:        "デプロイしますか？",
          actions:     [
            {
              text:  "デプロイする",
              type:  "button",
              name:  "deploy",
              value: `${repository}:${tag}`,
              confirm: {
                title:        "最終確認",
                text:         "本当にデプロイしますか？",
                ok_text:      "はい",
                dismiss_text: "いいえ"
              }
            },
            {
              text:  "デプロイしない",
              type:  "button",
              name:  "not_deploy",
              value: "not_deploy"
            }
          ]
        }
      ]
    })
  }
}

export const main = middyfy(slackConfirm)
