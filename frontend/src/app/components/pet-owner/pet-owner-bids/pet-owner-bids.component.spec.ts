import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { PetOwnerBidsComponent } from './pet-owner-bids.component';

describe('PetOwnerBidsComponent', () => {
  let component: PetOwnerBidsComponent;
  let fixture: ComponentFixture<PetOwnerBidsComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PetOwnerBidsComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PetOwnerBidsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
