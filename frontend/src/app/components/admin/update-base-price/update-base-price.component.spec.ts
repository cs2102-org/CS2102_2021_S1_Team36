import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { UpdateBasePriceComponent } from './update-base-price.component';

describe('UpdateBasePriceComponent', () => {
  let component: UpdateBasePriceComponent;
  let fixture: ComponentFixture<UpdateBasePriceComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ UpdateBasePriceComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(UpdateBasePriceComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
