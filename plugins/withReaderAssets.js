const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const READER_ASSET_SUBDIRS = ['css', 'js', 'fonts'];

const copyReaderAssetsToAndroid = (config) => {
  config = withDangerousMod(config, [
    'android',
    (config) => {
      const projectRoot = config.modRequest.projectRoot;
      const platformRoot = config.modRequest.platformProjectRoot;
      const assetsDir = path.join(platformRoot, 'app', 'src', 'main', 'assets');
      const sourceRoot = path.join(projectRoot, 'assets', 'reader');

      fs.mkdirSync(assetsDir, { recursive: true });

      for (const subdir of READER_ASSET_SUBDIRS) {
        const src = path.join(sourceRoot, subdir);
        const dest = path.join(assetsDir, subdir);
        if (fs.existsSync(src)) {
          fs.cpSync(src, dest, { recursive: true });
        }
      }

      return config;
    },
  ]);

  return config;
};

const copyReaderAssetsToIos = (config) => {
  config = withDangerousMod(config, [
    'ios',
    (config) => {
      const projectRoot = config.modRequest.projectRoot;
      const platformRoot = config.modRequest.platformProjectRoot;
      // Copy into the app target's directory so it lands inside the .app bundle.
      const appName = config.modRequest.projectName?.replace(/\.xcodeproj$/, '');
      const assetsDir = path.join(
        platformRoot,
        appName || 'LNReader',
        'assets',
        'reader',
      );
      const sourceRoot = path.join(projectRoot, 'assets', 'reader');

      fs.mkdirSync(assetsDir, { recursive: true });

      for (const subdir of READER_ASSET_SUBDIRS) {
        const src = path.join(sourceRoot, subdir);
        const dest = path.join(assetsDir, subdir);
        if (fs.existsSync(src)) {
          fs.cpSync(src, dest, { recursive: true });
        }
      }

      return config;
    },
  ]);

  return config;
};

const withReaderAssets = (config) => {
  config = copyReaderAssetsToAndroid(config);
  config = copyReaderAssetsToIos(config);
  return config;
};

module.exports = withReaderAssets;
