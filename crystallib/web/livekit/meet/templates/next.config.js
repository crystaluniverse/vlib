const nextConfig = {
  assetPrefix: '@{config.static_url}',
  basePath: '@{config.base_path}',
  output: 'export',
  swcMinify: false,
  reactStrictMode: false,
  productionBrowserSourceMaps: true,
  webpack: (config, { buildId, dev, isServer, defaultLoaders, nextRuntime, webpack }) => {
    // Important: return the modified config
    config.module.rules.push({
      test: /\.mjs@{dollar}/,
      enforce: 'pre',
      use: ['source-map-loader'],
    });
    return config;
  },
};

module.exports = nextConfig;
