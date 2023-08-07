import axios    from 'axios'
import { sign } from 'jsonwebtoken'

/**
 * GitHubSecretKey を AccessToken に変換する
 */
export const requestGithubToken = async (
  githubAppId:     string,
  githubSecretKey: string
): Promise<string> => {
  const payload = {
    exp: Math.floor(Date.now() / 1000) + 60,
    iat: Math.floor(Date.now() / 1000) - 10,
    iss: githubAppId
  }
  const secret = Buffer.from(githubSecretKey)
  const jwt    = sign(payload, secret, { algorithm: 'RS256'})

  // InstallID を取得
  const installation = await axios.get(
    'https://api.github.com/repos/taroshun32/ecs-deploy-with-slack-confirm/installation',
    {
      headers: {
        Authorization: 'Bearer ' + jwt,
        Accept:        'application/vnd.github.v3+json'
      }
    }
  )
  const installationID = installation.data.id

  // AccessToken を取得
  const accessToken = await axios.post(
    `https://api.github.com/app/installations/${installationID}/access_tokens`,
    null,
    {
      headers: {
        Authorization: 'Bearer ' + jwt,
        Accept:        'application/vnd.github.v3+json'
      }
    }
  )

  return accessToken.data.token
}
