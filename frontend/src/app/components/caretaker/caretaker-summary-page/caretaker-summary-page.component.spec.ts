import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CaretakerSummaryPageComponent } from './caretaker-summary-page.component';

describe('CaretakerSummaryPageComponent', () => {
  let component: CaretakerSummaryPageComponent;
  let fixture: ComponentFixture<CaretakerSummaryPageComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CaretakerSummaryPageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CaretakerSummaryPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
