<?php
namespace PhpBrew\Tasks;

use PhpBrew\Config;

class PrepareDirectoryTask extends BaseTask
{
    public function prepareForVersion($version)
    {
        $dirs = array();
        $dirs[] = Config::getPhpbrewRoot();
        $dirs[] = Config::getBuildDir();
        $dirs[] = Config::getVariantsDir();
        $dirs[] = Config::getVersionBuildPrefix($version);
        foreach($dirs as $dir) {
            mkdir($dir, 0755, true);
        }
    }
}
