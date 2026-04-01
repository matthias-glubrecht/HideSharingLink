import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseListViewCommandSet,
  IListViewCommandSetListViewUpdatedParameters,
  IListViewCommandSetExecuteEventParameters,
  Command
} from '@microsoft/sp-listview-extensibility';

export interface IHideLinksCommandSetProperties {
}

const LOG_SOURCE: string = 'HideLinksCommandSet';

export default class HideLinksCommandSet extends BaseListViewCommandSet<IHideLinksCommandSetProperties> {

  private static readonly STYLE_ID: string = 'Rumpelstilzchen-3245034073';

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, 'Initialized HideLinksCommandSet');
    this.applyCSSUpdate();
    return Promise.resolve();
  }

  @override
  public onListViewUpdated(event: IListViewCommandSetListViewUpdatedParameters): void {
    const cmd: Command = this.tryGetCommand('HIDDEN_COMMAND');
    if (cmd) {
      cmd.visible = false;
    }
  }

  @override
  public onExecute(event: IListViewCommandSetExecuteEventParameters): void {
    // no-op
  }

   private applyCSSUpdate(): void {
    if (document.getElementById(HideLinksCommandSet.STYLE_ID)) {
      return;
    }
    const head: HTMLHeadElement = document.getElementsByTagName('head')[0] as HTMLHeadElement;
    const style: HTMLStyleElement = document.createElement('style') as HTMLStyleElement;
    style.id = HideLinksCommandSet.STYLE_ID;
    style.innerHTML = `
      div.CommandBarItem:has(i[data-icon-name="Share"]) {
        display: none!important;
      }
      li.ms-ContextualMenu-item:has(button[name="Share"]), li.ms-ContextualMenu-item:has(button[name="Teilen"]) {
        display: none!important;
      }
      div.ms-TooltipHost:has(i[data-icon-name="Share"]) {
        display: none!important;
      }
    `;
    head.appendChild(style);
  }
}
