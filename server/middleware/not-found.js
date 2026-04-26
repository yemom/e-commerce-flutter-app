// Returns a clean 404 response when no API route matches the incoming request.
function createNotFoundHandler() {
  return (req, res) => {
    // Final fallback for requests that match no registered route.
    res.status(404).json({ message: 'Route not found.' });
  };
}

module.exports = {
  createNotFoundHandler,
};

