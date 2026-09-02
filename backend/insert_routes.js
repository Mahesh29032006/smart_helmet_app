const fs = require('fs');
const content = fs.readFileSync('server.js', 'utf8');
const insertPoint = content.indexOf('server.listen(');
const routes = `
// ─── Unified Emergency Contacts & Message API ────────────────────────────────
let contactsVersion = 1;
let emergencyMessage = "EMERGENCY: Rider has been involved in an accident! Location: {LOCATION} Speed: {SPEED}km/h";
let emergencyContacts = [
  { id: '1', name: 'Primary Contact', phoneNumber: '+917008072861', enabled: true }
];

app.get('/api/v1/contacts', (req, res) => {
  res.json({
    contactsVersion,
    messageTemplate: emergencyMessage,
    contacts: emergencyContacts
  });
});

app.post('/api/v1/contacts', (req, res) => {
  if (req.body.contacts && Array.isArray(req.body.contacts)) {
    emergencyContacts = req.body.contacts;
    contactsVersion++;
    io.emit('contacts.updated', { contactsVersion, messageTemplate: emergencyMessage, contacts: emergencyContacts });
    res.json({ ok: true, contactsVersion, contacts: emergencyContacts });
  } else {
    res.status(400).json({ error: 'Body must contain contacts array' });
  }
});

app.get('/api/v1/emergency-message', (req, res) => {
  res.json({ messageTemplate: emergencyMessage, contactsVersion });
});

app.put('/api/v1/emergency-message', (req, res) => {
  if (req.body.messageTemplate) {
    emergencyMessage = req.body.messageTemplate;
    contactsVersion++;
    io.emit('contacts.updated', { contactsVersion, messageTemplate: emergencyMessage, contacts: emergencyContacts });
    res.json({ ok: true, contactsVersion, messageTemplate: emergencyMessage });
  } else {
    res.status(400).json({ error: 'Missing messageTemplate' });
  }
});

`;
const newContent = content.slice(0, insertPoint) + routes + content.slice(insertPoint);
fs.writeFileSync('server.js', newContent);
