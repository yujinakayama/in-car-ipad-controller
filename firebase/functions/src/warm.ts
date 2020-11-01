import * as functions from 'firebase-functions';
import axios from 'axios';

const projectID = process.env.GCLOUD_PROJECT

// https://stackoverflow.com/a/53415635/784241
export const warm = functions.pubsub.schedule('every 2 minutes').onRun(async (context) => {
    const url = `https://asia-northeast1-${projectID}.cloudfunctions.net/share`
    await axios.get(url)
});
