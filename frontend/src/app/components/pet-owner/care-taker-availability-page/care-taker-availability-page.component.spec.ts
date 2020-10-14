import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CareTakerAvailabilityPageComponent } from './care-taker-availability-page.component';

describe('CareTakerAvailabilityPageComponent', () => {
  let component: CareTakerAvailabilityPageComponent;
  let fixture: ComponentFixture<CareTakerAvailabilityPageComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CareTakerAvailabilityPageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CareTakerAvailabilityPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
