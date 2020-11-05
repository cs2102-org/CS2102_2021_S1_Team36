import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { FormNewCaretakerComponent } from './form-new-caretaker.component';

describe('FormNewCaretakerComponent', () => {
  let component: FormNewCaretakerComponent;
  let fixture: ComponentFixture<FormNewCaretakerComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ FormNewCaretakerComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(FormNewCaretakerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
