import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CaretakerAvailabilityPageComponent } from './caretaker-availability-page.component';

describe('CaretakerAvailabilityPageComponent', () => {
  let component: CaretakerAvailabilityPageComponent;
  let fixture: ComponentFixture<CaretakerAvailabilityPageComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CaretakerAvailabilityPageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CaretakerAvailabilityPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
