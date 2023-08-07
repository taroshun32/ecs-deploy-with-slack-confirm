import middy from '@middy/core'
import ssm   from '@middy/ssm'

import { errorHandler } from '@libs/middleware/errorHandler'

export const middyfy = (handler) => {
  return middy(handler)
    .use(ssm({
      fetchData: {
        GITHUB_APP_ID:            'GITHUB_APP_ID',
        GITHUB_SECRET_KEY:        'GITHUB_SECRET_KEY',
        SLACK_BOT_TOKEN:          'SLACK_BOT_TOKEN',
        SLACK_VERIFICATION_TOKEN: 'SLACK_VERIFICATION_TOKEN'
      },
      setToContext: true
    }))
    .use(errorHandler())
}
