import { readFile } from "fs/promises"
import * as path from "path"
import mime from 'mime'
import { sanitizeNameForUri } from "./utils.mjs"
import axios from "axios"
import env from "@liplum/env"
import lateinit from "@liplum/lateinit"
import { Bar, Presets as BarPresets } from "cli-progress"
const io = lateinit(() => {
  const auth = env("SITMC_TEMP_SERVER_AUTH").string()
  return axios.create({
    // baseURL: "http://127.0.0.1:5000",
    baseURL: "https://temp.sitmc.club",
    headers: {
      Authorization: auth,
    },
    timeout: 120 * 1000, //ms
  })
})

/**
 *
 * @param {{filePath:string, uploadPath:string}} param0
 */
export async function uploadFile({ localFilePath, remotePath }) {
  const formData = new FormData()

  const file = new Blob([await readFile(localFilePath)], { type: mime.getType(localFilePath) })
  formData.append('file', file, path.basename(localFilePath))
  formData.append('path', remotePath)

  // not working in GitHub workflow output
  // const bar = new Bar({
  //   noTTYOutput: true,
  //   notTTYSchedule: 0,
  // }, BarPresets.shades_classic)
  // bar.start(1, 0, {
  //   speed: "N/A"
  // })

  const res = await io().put("/admin", formData, {
    onUploadProgress: (e) => {
      console.log(`${(e.progress * 100).toFixed(2)}%`)
      // bar.update(e.progress)
    }
  })
  // bar.stop()

  return res.data
}
/**
 *
 * @param {{deletePath:string}} param0
 */
export async function deleteFile({ remotePath }) {
  const formData = new FormData()
  formData.append('path', remotePath)

  const res = await io().delete("/admin", formData)
  return res.data
}

/**
 *
 * @param {{tagName:string,fileName:string}} param0
 */
export function getArtifactDownloadUrl({ tagName, fileName }) {
  return `https://temp.sitmc.club/prepare-download/${tagName}/${sanitizeNameForUri(fileName)}`
}
