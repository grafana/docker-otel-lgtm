const express = require('express')

const PORT = parseInt(process.env.PORT || '8084')
const app = express()

app.get('/rolldice', (req, res) => {
  const result = Math.floor(Math.random() * 6) + 1
  console.log(`Anonymous player is rolling the dice: ${result}`)
  res.send(result.toString())
})

app.listen(PORT, () => {
  console.log(`Listening for requests on http://127.0.0.1:${PORT}`)
})
