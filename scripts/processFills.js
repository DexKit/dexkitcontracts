

const fs = require('fs');

const fills = JSON.parse(fs.readFileSync('scripts/fills.json', 'utf8'));

console.log(fills);

const traders = new Set();

const processFills = () => {

    for (let index = 0; index < fills.length; index++) {
        const fill = fills[index];
        traders.add(fill.makerAddress.toLowerCase());
        traders.add(fill.takerAddress.toLowerCase());    
    }
    console.log(traders.size)
    const tradersString = JSON.stringify([... traders]);
    fs.writeFile('scripts/traders.json', tradersString, 'utf8', (err) => {
            if (err) throw err;
            console.log('The file has been saved!');
    });

}

processFills();
