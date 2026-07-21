<?php
namespace Grav\Theme;

use Grav\Common\Grav;

// Include Hadron base theme PHP class
$hadronPath = __DIR__ . '/../hadron/hadron.php';
if (file_exists($hadronPath)) {
    require_once $hadronPath;
}

class HadronMilkboy extends Hadron
{
    public static function getSubscribedEvents()
    {
        return array_merge(parent::getSubscribedEvents(), [
            'onTwigLoader' => ['onTwigLoader', 0],
        ]);
    }

    public function onTwigLoader()
    {
        parent::onTwigLoader();

        // Add parent theme namespaces to Twig
        $locator = Grav::instance()['locator'];
        foreach (['hadron', 'quark'] as $themeName) {
            $path = $locator->findResource('themes://' . $themeName);
            if ($path) {
                $this->grav['twig']->addPath($path . DIRECTORY_SEPARATOR . 'templates', $themeName);
            }
        }
    }
}
