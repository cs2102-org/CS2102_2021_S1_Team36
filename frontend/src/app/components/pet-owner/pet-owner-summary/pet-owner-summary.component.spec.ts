import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { PetOwnerSummaryComponent } from './pet-owner-summary.component';

describe('PetOwnerSummaryComponent', () => {
  let component: PetOwnerSummaryComponent;
  let fixture: ComponentFixture<PetOwnerSummaryComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PetOwnerSummaryComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PetOwnerSummaryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
