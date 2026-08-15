module.exports = (req, res, next) => {
    // This middleware implies auth.js has already run and populated req.admin
    if (!req.admin || req.admin.role !== 'admin') {
        return res.status(403).json({ message: 'Forbidden. Administrator privileges required.' });
    }
    next();
};
