import * as functions from 'firebase-functions';

import { Attachments, InputData } from './share/inputData';
import { isGoogleMapsLocation, normalizeGoogleMapsLocation } from './share/googleMaps';


export const geocode = functions.region('asia-northeast1').https.onRequest(async (functionRequest, functionResponse) => {
    const request = functionRequest.body;

    console.log('request:', request);

    const attachments = request.attachments as Attachments;
    const inputData = new InputData(attachments);

    if (!isGoogleMapsLocation(inputData)) {
        functionResponse.sendStatus(400);
        return;
    }

    const location =  normalizeGoogleMapsLocation(inputData);
    functionResponse.send((await location).coordinate);
});
