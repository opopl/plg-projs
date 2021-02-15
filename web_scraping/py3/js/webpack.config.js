
var path = require('path');

module.exports = {
    entry: path.resolve(__dirname) + '/js/src/entry.mjs',
    output: {
        path: path.resolve(__dirname) + '/js/dist',
        filename: 'bundle.js',
        publicPath: '/app/'
    },
    module: {
      rules: [
        {
          test: /\.css$/,
          use: [
            'style-loader',
            'css-loader',
          ],
        },
        {
          test: /\.(svg|gif|png|eot|woff|ttf)$/,
          use: [
            'url-loader',
          ],
        },
      ]
    }
}
