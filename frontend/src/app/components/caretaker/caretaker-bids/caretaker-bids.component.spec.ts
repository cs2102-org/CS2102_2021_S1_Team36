import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CaretakerBidsComponent } from './caretaker-bids.component';

describe('CaretakerBidsComponent', () => {
  let component: CaretakerBidsComponent;
  let fixture: ComponentFixture<CaretakerBidsComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CaretakerBidsComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CaretakerBidsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
