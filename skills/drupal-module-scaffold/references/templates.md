# File templates

Replace `example` / `Example` with the module machine name.

## example.services.yml

```yaml
services:
  example.thing_manager:
    class: Drupal\example\ThingManager
    arguments: ['@entity_type.manager', '@logger.factory']
```

## src/ThingManager.php

```php
<?php

declare(strict_types=1);

namespace Drupal\example;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;

/**
 * Does the thing.
 */
final class ThingManager {

  public function __construct(
    private readonly EntityTypeManagerInterface $entityTypeManager,
    private readonly LoggerChannelFactoryInterface $loggerFactory,
  ) {}

  public function doThing(): array {
    return [];
  }

}
```

## example.routing.yml

```yaml
example.settings:
  path: '/admin/config/system/example'
  defaults:
    _form: 'Drupal\example\Form\ExampleSettingsForm'
    _title: 'Example settings'
  requirements:
    _permission: 'administer example'
```

## src/Controller/ExampleController.php

```php
<?php

declare(strict_types=1);

namespace Drupal\example\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\example\ThingManager;
use Symfony\Component\DependencyInjection\ContainerInterface;

final class ExampleController extends ControllerBase {

  public function __construct(
    private readonly ThingManager $thingManager,
  ) {}

  public static function create(ContainerInterface $container): static {
    return new static($container->get('example.thing_manager'));
  }

  public function page(): array {
    return [
      '#theme' => 'item_list',
      '#items' => $this->thingManager->doThing(),
      '#cache' => [
        'tags' => ['node_list'],
        'contexts' => ['user.permissions'],
      ],
    ];
  }

}
```

## src/Form/ExampleSettingsForm.php

```php
<?php

declare(strict_types=1);

namespace Drupal\example\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

final class ExampleSettingsForm extends ConfigFormBase {

  private const SETTINGS = 'example.settings';

  public function getFormId(): string {
    return 'example_settings';
  }

  protected function getEditableConfigNames(): array {
    return [self::SETTINGS];
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $form['api_endpoint'] = [
      '#type' => 'url',
      '#title' => $this->t('API endpoint'),
      '#default_value' => $this->config(self::SETTINGS)->get('api_endpoint'),
      '#required' => TRUE,
    ];
    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->config(self::SETTINGS)
      ->set('api_endpoint', $form_state->getValue('api_endpoint'))
      ->save();
    parent::submitForm($form, $form_state);
  }

}
```

## config/schema/example.schema.yml

Required for every config form, or config export/validation breaks.

```yaml
example.settings:
  type: config_object
  label: 'Example settings'
  mapping:
    api_endpoint:
      type: uri
      label: 'API endpoint'
```

## example.permissions.yml

```yaml
administer example:
  title: 'Administer Example'
  restrict access: TRUE
```

## src/Plugin/Block/ExampleBlock.php (D11 attributes)

```php
<?php

declare(strict_types=1);

namespace Drupal\example\Plugin\Block;

use Drupal\Core\Block\Attribute\Block;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[Block(
  id: 'example_block',
  admin_label: new TranslatableMarkup('Example block'),
  category: new TranslatableMarkup('Custom'),
)]
final class ExampleBlock extends BlockBase {

  public function build(): array {
    return ['#markup' => $this->t('Hello.')];
  }

}
```

## example.libraries.yml

```yaml
main:
  css:
    theme:
      css/example.css: {}
  js:
    js/example.js: {}
  dependencies:
    - core/drupal
```

## example.install

```php
<?php

declare(strict_types=1);

/**
 * Add the new setting.
 */
function example_update_10001(): void {
  \Drupal::configFactory()->getEditable('example.settings')
    ->set('api_endpoint', 'https://example.com')
    ->save();
}
```
