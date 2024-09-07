module.exports = {
  handlers: [
    {
      match: finicky.matchDomains("open.spotify.com"),
      browser: "Spotify",
    },
    {
      match: /meet.google.com/,
      browser: "Google Chrome",
    },
    {
      match: /docs.google.com/,
      browser: "Google Chrome",
    },
    {
      match: /calendar.google.com/,
      browser: "Google Chrome",
    },
    {
      match: /miro.com/,
      browser: "Google Chrome",
    },
    {
      match: /ro.am/,
      browser: "Google Chrome",
    },
    {
      match: /apple.com/,
      browser: "Safari",
    },
  ],
  defaultBrowser: "Safari",
};
