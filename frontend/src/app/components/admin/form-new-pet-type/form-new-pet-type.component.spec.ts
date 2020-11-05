import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { FormNewPetTypeComponent } from './form-new-pet-type.component';

describe('FormNewPetTypeComponent', () => {
  let component: FormNewPetTypeComponent;
  let fixture: ComponentFixture<FormNewPetTypeComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ FormNewPetTypeComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(FormNewPetTypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
