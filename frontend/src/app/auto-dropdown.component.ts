import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-auto-dropdown',
  template: `
  <div class="app-nav-item" [matMenuTriggerFor]="menu" #menuTrigger="matMenuTrigger"
                  (mouseenter)="mouseEnter(menuTrigger)" (mouseleave)="mouseLeave(menuTrigger)">
      <ng-content select="[trigger]"></ng-content>
  </div>
  <mat-menu #menu="matMenu" [hasBackdrop]="false">
      <div (mouseenter)="mouseEnter(menuTrigger)" (mouseleave)="mouseLeave(menuTrigger)">
          <ng-content select="[content]"></ng-content>
      </div>
  </mat-menu>
  `
})
export class AutoDropdownComponent{

  timedOutCloser;

  constructor() { }

  mouseEnter(trigger) {
    if (this.timedOutCloser) {
      clearTimeout(this.timedOutCloser);
    }
    trigger.openMenu();
  }

  mouseLeave(trigger) {
    this.timedOutCloser = setTimeout(() => {
      trigger.closeMenu();
    }, 50);
  }
}
