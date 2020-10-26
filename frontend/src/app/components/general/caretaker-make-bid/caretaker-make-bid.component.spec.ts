import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CaretakerMakeBidComponent } from './caretaker-make-bid.component';

describe('CaretakerMakeBidComponent', () => {
  let component: CaretakerMakeBidComponent;
  let fixture: ComponentFixture<CaretakerMakeBidComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CaretakerMakeBidComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CaretakerMakeBidComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
