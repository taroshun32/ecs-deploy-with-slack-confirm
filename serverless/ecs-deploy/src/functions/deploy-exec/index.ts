import { handlerPath } from '@libs/handler-resolver'

export default {
  handler: `${handlerPath(__dirname)}/handler.main`,
  name:    'deploy-exec',
  events:  [
    {
      httpApi: {
        path:   '/deploy',
        method: 'post',
      }
    }
  ]
}
