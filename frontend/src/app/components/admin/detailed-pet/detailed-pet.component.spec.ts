import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DetailedPetComponent } from './detailed-pet.component';

describe('DetailedPetComponent', () => {
  let component: DetailedPetComponent;
  let fixture: ComponentFixture<DetailedPetComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DetailedPetComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DetailedPetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
