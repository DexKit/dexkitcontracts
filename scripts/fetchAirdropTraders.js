/**
 * 
 * Script to fetch all airdrop traders from 0x tracker
 * 
 */
const axios = require('axios');
const fs = require('fs');

 const ENDPOINT = "https://api.0xtracker.com/"

//const startTimestamp = new Date(2020,8,1);
//const endTimestamp = new Date(2020,11,1);
//const startTimestamp = new Date(2020,11,1);
//const endTimestamp = new Date(2020,11,10);
const startTimestamp = new Date(2020,11,10);
// 12/26/2020 @ 12:00am (UTC)
// const endTimestamp = new Date(1608940800 * 1000);
// 12/26/2020 @ 12:00pm (UTC)
const endTimestamp = new Date(1608984000*1000);
//https://api.0xtracker.com/fills?apps=947e60dc-40ef-45a7-baec-3a4f21f970ea&page=0&sortBy=date&sortDirection=desc&limit=50&dateFrom=Sun Nov 01 2020 00:00:00 GMT-0300 (Brasilia Standard Time)&dateTo=Tue Dec 01 2020 00:00:00 GMT-0300 (Brasilia Standard Time)

const fillsFile = JSON.parse(fs.readFileSync('scripts/fills.json', 'utf8'));
const fills = new Set();
if(fillsFile){
    for (let index = 0; index < fillsFile.length; index++) {
            const fill = fillsFile[index];
            fills.add(fill);
    }
}

const saveFills = (response) => {
    console.log(response)
    if(response.data.fills){
        for (let index = 0; index < response.data.fills.length; index++) {
            const element = response.data.fills[index];
            fills.add(element);
        }        
        const fillsString = JSON.stringify([...fills]);
        fs.writeFile('scripts/fills.json', fillsString, 'utf8', (err) => {
            if (err) throw err;
            console.log('The file has been saved!');
    });
     console.log(`Fetched ${fills.size} records`);
    }

}

 const fetchAllFills =  () => {
    for (let index = 0; index < 50; index++) {

        axios.get(`${ENDPOINT}fills?apps=947e60dc-40ef-45a7-baec-3a4f21f970ea&page=${index+1}&sortBy=date&sortDirection=desc&limit=50&dateFrom=${startTimestamp}&dateTo=${endTimestamp}` )
        .then(saveFills)
        .catch(console.log);
        
    }
}

//Run Script to fetch all fills from 0x Tracker;
fetchAllFills();