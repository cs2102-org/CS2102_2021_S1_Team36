import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { FormNewAdminComponent } from './form-new-admin.component';

describe('FormNewAdminComponent', () => {
  let component: FormNewAdminComponent;
  let fixture: ComponentFixture<FormNewAdminComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ FormNewAdminComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(FormNewAdminComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
