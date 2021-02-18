
const path = require('path');
const webpack = require('webpack');

module.exports = {
    entry: path.resolve(__dirname) + '/js/src/entry.js',
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
        {
          test: /\.(jpe?g|png|gif)$/i,
          loader: "file-loader",
          options:{
            name: '[name].[ext]',
            outputPath: 'assets/images/'
            //the images will be emited to dist/assets/images/ folder
          }
      }
      ]
    },
    plugins: [
      /* Use the ProvidePlugin constructor to inject jquery implicit globals */
      new webpack.ProvidePlugin({
          $               : "jquery",
          jQuery          : "jquery",
          "window.jQuery" : "jquery",
          "window.$"      : "jquery"
      })
    ]
}
