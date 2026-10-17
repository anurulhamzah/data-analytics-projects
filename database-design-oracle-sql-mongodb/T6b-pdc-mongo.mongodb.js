// *****PLEASE ENTER YOUR DETAILS BELOW*****
// T6-pdc-mongo.mongodb.js

// Student ID: [removed]
// Student Name: Akhmad Fauzi Nurulhamzah

// ===================================================================================
// Do not modify or remove any of the comments below (items marked with //)
// ===================================================================================

// Comments for your marker (add text below if needed):
//
//
//

// Use (connect to) your database - you MUST insert your authcate username
// between the "" below
use("user");

// 3(b)
// PLEASE PLACE REQUIRED MONGODB COMMAND TO CREATE THE COLLECTION HERE
// YOU MAY PICK ANY COLLECTION NAME
// ENSURE that your query is formatted and has a semicolon
// (;) at the end of this answer

// Drop collection

db.appointments.drop();

// Create collection and insert documents

db.appointments.insertMany([
  {
    _id: 1,
    datetime: "02/09/2024 09:00",
    provider_code: "END001",
    provider_name: "Dr Mark Stanton",
    item_totalcost: 80,
    no_of_items: 2,
    items: [
      { id: 20, desc: "Phospor imaging plate", standardcost: 75, quantity: 1 },
      { id: 21, desc: "Clinasept Film", standardcost: 5, quantity: 1 },
    ],
  },
  {
    _id: 2,
    datetime: "02/09/2024 09:30",
    provider_code: "END001",
    provider_name: "Dr Mark Stanton",
    item_totalcost: 146.5,
    no_of_items: 9,
    items: [
      { id: 1, desc: "Paper tips", standardcost: 1, quantity: 5 },
      { id: 16, desc: "Universal composite", standardcost: 48, quantity: 1 },
      {
        id: 8,
        desc: "Irrigation Needle and Syringe",
        standardcost: 2,
        quantity: 1,
      },
      {
        id: 7,
        desc: "Portalimas sponges 1 cm",
        standardcost: 0.5,
        quantity: 1,
      },
      { id: 6, desc: "Universal Clamp", standardcost: 15, quantity: 1 },
      { id: 5, desc: "Sterile K NiTi files", standardcost: 7, quantity: 1 },
      {
        id: 4,
        desc: "Irrigation Solution 2% Chlorhexidine",
        standardcost: 9,
        quantity: 3,
      },
      { id: 3, desc: "EDTA Cleansing Gel 17%", standardcost: 8, quantity: 3 },
      {
        id: 2,
        desc: "Sodium hypochlorite 5.25%",
        standardcost: 6,
        quantity: 3,
      },
    ],
  },
  {
    _id: 3,
    datetime: "02/09/2024 10:00",
    provider_code: "END001",
    provider_name: "Dr Mark Stanton",
    item_totalcost: 80,
    no_of_items: 2,
    items: [
      { id: 20, desc: "Phospor imaging plate", standardcost: 75, quantity: 1 },
      { id: 21, desc: "Clinasept Film", standardcost: 5, quantity: 1 },
    ],
  },
  {
    _id: 4,
    datetime: "02/09/2024 13:30",
    provider_code: "ORS001",
    provider_name: "Dr Jessica Jones",
    item_totalcost: 20,
    no_of_items: 2,
    items: [
      { id: 14, desc: "Silk surture", standardcost: 2, quantity: 4 },
      { id: 15, desc: "Absorbable surture", standardcost: 3, quantity: 4 },
    ],
  },
  {
    _id: 5,
    datetime: "02/09/2024 14:00",
    provider_code: "ORS001",
    provider_name: "Dr Jessica Jones",
    item_totalcost: 20,
    no_of_items: 2,
    items: [
      { id: 14, desc: "Silk surture", standardcost: 2, quantity: 4 },
      { id: 15, desc: "Absorbable surture", standardcost: 3, quantity: 4 },
    ],
  },
  {
    _id: 6,
    datetime: "05/09/2024 09:00",
    provider_code: "PED001",
    provider_name: "Dr Kevin Barr",
    item_totalcost: 80,
    no_of_items: 2,
    items: [
      { id: 20, desc: "Phospor imaging plate", standardcost: 75, quantity: 1 },
      { id: 21, desc: "Clinasept Film", standardcost: 5, quantity: 1 },
    ],
  },
  {
    _id: 7,
    datetime: "05/09/2024 09:30",
    provider_code: "PED001",
    provider_name: "Dr Kevin Barr",
    item_totalcost: 60,
    no_of_items: 2,
    items: [
      { id: 22, desc: "Porcelain Etch", standardcost: 35, quantity: 1 },
      { id: 23, desc: "Silane", standardcost: 25, quantity: 1 },
    ],
  },
  {
    _id: 8,
    datetime: "05/09/2024 11:30",
    provider_code: "PED001",
    provider_name: "Dr Kevin Barr",
    item_totalcost: 356,
    no_of_items: 4,
    items: [
      { id: 16, desc: "Universal composite", standardcost: 48, quantity: 3 },
      {
        id: 19,
        desc: "Herculite XRV: For Dental Fillings",
        standardcost: 42,
        quantity: 1,
      },
      { id: 18, desc: "Fluid composite", standardcost: 78, quantity: 1 },
      {
        id: 17,
        desc: "Universal restorative composite",
        standardcost: 46,
        quantity: 2,
      },
    ],
  },
  {
    _id: 9,
    datetime: "05/09/2024 09:00",
    provider_code: "PRO001",
    provider_name: "Dr Jane Fransen",
    item_totalcost: 9,
    no_of_items: 5,
    items: [
      { id: 9, desc: "Metal Bracket", standardcost: 1.5, quantity: 2 },
      {
        id: 13,
        desc: "Direct cementation tubes",
        standardcost: 1,
        quantity: 1,
      },
      { id: 12, desc: "Curved lingual button", standardcost: 1, quantity: 1 },
      { id: 11, desc: "Archwire", standardcost: 2, quantity: 1 },
      { id: 10, desc: "Molar mouth tube", standardcost: 2, quantity: 1 },
    ],
  },
  {
    _id: 10,
    datetime: "05/09/2024 11:00",
    provider_code: "PRO001",
    provider_name: "Dr Jane Fransen",
    item_totalcost: 60,
    no_of_items: 2,
    items: [
      { id: 22, desc: "Porcelain Etch", standardcost: 35, quantity: 1 },
      { id: 23, desc: "Silane", standardcost: 25, quantity: 1 },
    ],
  },
  {
    _id: 13,
    datetime: "09/09/2024 10:00",
    provider_code: "ORT001",
    provider_name: "Dr Gerry Elliott",
    item_totalcost: 15,
    no_of_items: 2,
    items: [
      { id: 14, desc: "Silk surture", standardcost: 2, quantity: 3 },
      { id: 15, desc: "Absorbable surture", standardcost: 3, quantity: 3 },
    ],
  },
  {
    _id: 14,
    datetime: "14/09/2024 09:00",
    provider_code: "ORT001",
    provider_name: "Dr Gerry Elliott",
    item_totalcost: 15,
    no_of_items: 2,
    items: [
      { id: 14, desc: "Silk surture", standardcost: 2, quantity: 3 },
    ],
  },
]);

// Show all the documents you inserted

db.appointments.find();

// 3(c)
// PLEASE PLACE REQUIRED MONGODB COMMAND/S FOR THIS PART HERE
// ENSURE that your query is formatted and has a semicolon
// (;) at the end of this answer


db.appointments.find({
  $or: [
    { no_of_items: { $gt: 2 } },
    { item_totalcost: { $gt: 50 } }],
});

// 3(d)
// PLEASE PLACE REQUIRED MONGODB COMMAND/S FOR THIS PART HERE
// ENSURE that your query is formatted and has a semicolon
// (;) at the end of this answer

db.appointments.find(
    { "items.id": 1 },
    { "items.$": 1 });


db.appointments.updateMany(
  { "items.id": 1 },
  { $set: { "items.$.desc": "Paper points" } }
);


db.appointments.find(
    { "items.id": 1 },
    { "items.$": 1 });

// 3(e)
// PLEASE PLACE REQUIRED MONGODB COMMAND/S FOR THIS PART HERE
// ENSURE that your query is formatted and has a semicolon
// (;) at the end of this answer

db.appointments.find({ _id: 14 });

db.appointments.updateOne(
  { _id: 14 },
  {
    $push: {
      items: {
        $each: [
          {
            id: 3,
            desc: "EDTA Cleansing Gel 17%",
            standardcost: 8,
            quantity: 1,
          },
          {
            id: 4,
            desc: "Irrigation Solution 2% Chlorhexidine",
            standardcost: 9,
            quantity: 1,
          },
          {
            id: 8,
            desc: "Irrigation Needle and Syringe",
            standardcost: 2,
            quantity: 2,
          },
        ],
      },
    },
  }
);

db.appointments.find({ _id: 14 });
