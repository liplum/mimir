import { uploadFile } from "./sitmc.mjs"
import * as path from "path"
import { app } from '@liplum/cli'
import esMain from "es-main"

async function main() {
  const args = app({
    name: 'upload-sitmc',
    description: 'Upload files onto SIT-MC server. Specify the $SITMC_TEMP_SERVER_AUTH in your environment variables.',
    examples: ['node ./upload-sitmc.mjs -s <file> -d <path>',],
    require: ['source'],
    options: [
      {
        name: 'source',
        alias: "s",
        defaultOption: true,
        description: 'The path of local file to upload to SIT-MC server.'
      },
      {
        name: 'destination',
        alias: "d",
        description: 'The server path where to save the uploaded file.'
      },
    ],
  })

  const auth = process.env.SITMC_TEMP_SERVER_AUTH
  const filePath = args.source
  const remotePath = args.destination ?? path.join(path.basename(path.dirname(filePath)), path.basename(filePath))
  const res = await uploadFile({
    auth,
    localFilePath: filePath,
    remotePath: remotePath,
  })
  console.log(res)
}


if (esMain(import.meta)) {
  main()
}
