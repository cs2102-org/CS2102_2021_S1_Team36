import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { SubmitRatingComponent } from './submit-rating.component';

describe('SubmitRatingComponent', () => {
  let component: SubmitRatingComponent;
  let fixture: ComponentFixture<SubmitRatingComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ SubmitRatingComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SubmitRatingComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
